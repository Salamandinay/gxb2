local BaseWindow = import(".BaseWindow")
local Arena3V3ResultWindow = class("Arena3V3ResultWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")

function Arena3V3ResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.onOpenCallback = nil
	self.StageTable = xyd.tables.stageTable
	self.isWin_ = false

	if params and params.callback ~= nil then
		self.callback = params.callback
	end

	if params and params.onOpenCallback ~= nil then
		self.onOpenCallback = params.onOpenCallback
	end

	self.battleParams = params.battleParams
	self.mapType = self.battleParams.map_type
	self.battleType = params.battle_type
	self.isWin_ = self.battleParams.is_win == 1
end

function Arena3V3ResultWindow:getUIComponent()
	local trans = self.window_.transform
	self.winGroup = trans:NodeByName("winGroup").gameObject
	self.pvpGroup = self.winGroup:NodeByName("pvpGroup").gameObject
	self.pveDropGroup = self.winGroup:NodeByName("pveDropGroup").gameObject
	self.damageGroup = self.winGroup:NodeByName("damageGroup").gameObject
	self.confirmBtn = self.winGroup:NodeByName("confirmBtn").gameObject
	self.labelResult1_ = self.pvpGroup:ComponentByName("labelResult1_", typeof(UILabel))
	self.labelResult2_ = self.pvpGroup:ComponentByName("labelResult2_", typeof(UILabel))
	self.leftPlayerGroup = self.pvpGroup:NodeByName("leftPlayerGroup").gameObject
	self.rightPlayerGroup = self.pvpGroup:NodeByName("rightPlayerGroup").gameObject
	self.groupLeftLabels_ = self.leftPlayerGroup:NodeByName("groupLeftLabels_").gameObject
	self.groupLeftIcon_ = self.leftPlayerGroup:NodeByName("groupLeftIcon_").gameObject
	self.labelLeftPlayerName = self.groupLeftLabels_:ComponentByName("labelLeftPlayerName", typeof(UILabel))
	self.labelLeftScoreText = self.groupLeftLabels_:ComponentByName("labelLeftScoreText", typeof(UILabel))
	self.leftScoreGroup = self.groupLeftLabels_:NodeByName("leftScoreGroup").gameObject
	self.levelLImg = self.groupLeftLabels_:ComponentByName("imgGroup/levelImg", typeof(UISprite))
	self.levelLImg2 = self.groupLeftLabels_:ComponentByName("imgGroup/levelImg2", typeof(UISprite))
	self.labelLeftScore = self.leftScoreGroup:ComponentByName("labelLeftScore", typeof(UILabel))
	self.labelLeftScoreChange = self.leftScoreGroup:ComponentByName("labelLeftScoreChange", typeof(UILabel))
	self.groupRightLabels_ = self.rightPlayerGroup:NodeByName("groupRightLabels_").gameObject
	self.groupRightIcon_ = self.rightPlayerGroup:NodeByName("groupRightIcon_").gameObject
	self.labelRightPlayerName = self.groupRightLabels_:ComponentByName("labelRightPlayerName", typeof(UILabel))
	self.labelRightScoreText = self.groupRightLabels_:ComponentByName("labelRightScoreText", typeof(UILabel))
	self.rightScoreGroup = self.groupRightLabels_:NodeByName("rightScoreGroup").gameObject
	self.levelRImg = self.groupRightLabels_:ComponentByName("imgGroup/levelImg", typeof(UISprite))
	self.levelRImg2 = self.groupRightLabels_:ComponentByName("imgGroup/levelImg2", typeof(UISprite))
	self.labelRightScore = self.rightScoreGroup:ComponentByName("labelRightScore", typeof(UILabel))
	self.labelRightScoreChange = self.rightScoreGroup:ComponentByName("labelRightScoreChange", typeof(UILabel))
	self.labelDamage1 = self.damageGroup:ComponentByName("labelDamage1", typeof(UILabel))
	self.labelDamage2 = self.damageGroup:ComponentByName("labelDamage2", typeof(UILabel))
	self.confirmBtnLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
	self.textImg = self.winGroup:ComponentByName("textImg", typeof(UITexture))
end

function Arena3V3ResultWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local effect = "shengli_blackboard"

	if not self.isWin_ then
		effect = "shibai_blackboard"
	end

	xyd.setUITextureByNameAsync(self.textImg, effect .. "_" .. xyd.Global.lang, true)

	if self.isWin_ then
		xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_WIN)
	else
		xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_LOSE)
	end

	local spine = xyd.Spine.new(self.winGroup)

	spine:setInfo(effect, function ()
		spine:changeAttachment("zi1", self.textImg)
		spine:SetLocalPosition(0, 130, 0)
		spine:play("texiao01", 1, 1, function ()
			spine:play("texiao02", 0, 1)
		end)
	end)

	self.layoutTimer = self:getTimer(function ()
		self:initLayout()
	end, 0.3, 1)

	self.layoutTimer:Start()
end

function Arena3V3ResultWindow:initLayout()
	self.layeoutSequence = self:getSequence(function ()
		self.confirmBtn:SetActive(true)
	end)

	self.pvpGroup:SetActive(false)
	self.pveDropGroup:SetActive(false)

	self.confirmBtnLabel.text = __("CONFIRM")

	xyd.setBgColorType(self.confirmBtn, xyd.ButtonBgColorType.white_btn_70_70)

	if self.battleType == xyd.BattleType.ARENA_3v3 then
		self:initArena3v3()
		self.pvpGroup:SetLocalScale(0.01, 0.01, 1)
		self.pvpGroup:SetActive(true)
		self.layeoutSequence:Append(self.pvpGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.ARENA_TEAM then
		self:initArenaTeam()
		self.pvpGroup:SetLocalScale(0.01, 0.01, 1)
		self.pvpGroup:SetActive(true)
		self.layeoutSequence:Append(self.pvpGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER then
		self:initArenaScore()
		self.pvpGroup:SetLocalScale(0.01, 0.01, 1)
		self.pvpGroup:SetActive(true)
		self.layeoutSequence:Append(self.pvpGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
		self.pvpGroup:SetActive(true)
	end

	UIEventListener.Get(self.confirmBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("battle_window")
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if self.onOpenCallback then
		self:onOpenCallback()
	end
end

function Arena3V3ResultWindow:initArenaTeam()
	self.labelLeftPlayerName.text = self.battleParams.self_info.team_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.team_name

	for i = 1, 3 do
		local paramsA = {
			avatarID = self.battleParams.self_info.players[i].avatar_id,
			lev = self.battleParams.self_info.players[i].lev,
			avatar_frame_id = self.battleParams.self_info.players[i].avatar_frame_id
		}
		local paramsB = {
			avatarID = self.battleParams.enemy_info.players[i].avatar_id,
			lev = self.battleParams.enemy_info.players[i].lev,
			avatar_frame_id = self.battleParams.enemy_info.players[i].avatar_frame_id
		}
		local iconA = PlayerIcon.new(self.groupLeftIcon_)
		local iconB = PlayerIcon.new(self.groupRightIcon_)

		iconA:setInfo(paramsA)
		iconB:setInfo(paramsB)

		if self.battleParams.self_info.leader_id == self.battleParams.self_info.players[i].player_id then
			iconA:setCaptain(true)
		end

		if self.battleParams.enemy_info.leader_id == self.battleParams.enemy_info.players[i].player_id then
			iconB:setCaptain(true)
		end

		iconA:setScale(0.7)
		iconB:setScale(0.7)
	end

	self.groupLeftIcon_:SetLocalPosition(-20, 0, 0)
	self.groupRightIcon_:SetLocalPosition(20, 0, 0)

	self.labelLeftScoreText.text = __("SCORE2")
	self.labelRightScoreText.text = __("SCORE2")
	self.labelLeftScore.text = self.battleParams.self_info.score
	self.labelRightScore.text = self.battleParams.enemy_info.score
	local changeTextLeft = tostring(self.battleParams.self_change)
	local changeTextRight = tostring(self.battleParams.enemy_change)

	if self.battleParams.self_change > 0 then
		changeTextLeft = "+" .. changeTextLeft
	end

	if self.battleParams.enemy_change > 0 then
		changeTextRight = "+" .. changeTextRight
	end

	self.labelLeftScoreChange.text = "(" .. tostring(changeTextLeft) .. ")"
	self.labelRightScoreChange.text = "(" .. tostring(changeTextRight) .. ")"
	local aWinNum = 0
	local reports = self.battleParams.battle_reports

	for _, report in pairs(reports) do
		if report.isWin == 1 then
			aWinNum = aWinNum + 1
		end
	end

	self.labelResult1_.text = tostring(aWinNum)
	self.labelResult2_.text = tostring(#reports - aWinNum)
end

function Arena3V3ResultWindow:initArenaScore()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = nil

	if self.battleParams.enemy_info.avatar_id then
		paramsB = {
			avatarID = self.battleParams.enemy_info.avatar_id,
			lev = self.battleParams.enemy_info.lev,
			avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
		}
	else
		local table_id = self.battleParams.enemy_info.player_id
		paramsB = {
			avatarID = xyd.tables.arenaAllServerRobotTable:getAvatar(table_id),
			lev = xyd.tables.arenaAllServerRobotTable:getLev(table_id)
		}
		self.labelRightPlayerName.text = xyd.tables.arenaAllServerRobotTable:getName(table_id)
	end

	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)
	self.labelLeftScoreText.gameObject:SetActive(false)
	self.labelRightScoreText:SetActive(false)

	local enemyScore = self.battleParams.enemy_info.score or 0
	local selfScore = self.battleParams.score or 0
	local rankType = xyd.tables.arenaAllServerRankTable:getRankType(selfScore, self.battleParams.rank)
	local level = xyd.tables.arenaAllServerRankTable:getRankLevel(selfScore, self.battleParams.rank)

	if level == 21 then
		self.levelLImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelLImg, nil, "as_rank_icon_5", nil, , true)
	elseif level == 22 then
		self.levelLImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelLImg, nil, "as_rank_icon_6", nil, , true)
	else
		local level_ = math.fmod(level - 1, 5) + 1

		self.levelLImg2.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.levelLImg, nil, "as_rank_icon_" .. rankType, nil, , true)
		xyd.setUISpriteAsync(self.levelLImg2, nil, "as_rank_icon_" .. rankType .. "_" .. level_, nil, , true)
	end

	local rankType = xyd.tables.arenaAllServerRankTable:getRankType(enemyScore, self.battleParams.enemy_info.rank)
	local level = xyd.tables.arenaAllServerRankTable:getRankLevel(enemyScore, self.battleParams.enemy_info.rank)

	if level == 21 then
		self.levelRImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelRImg, nil, "as_rank_icon_5", nil, , true)
	elseif level == 22 then
		self.levelRImg2.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levelRImg, nil, "as_rank_icon_6", nil, , true)
	else
		local level_ = math.fmod(level - 1, 5) + 1

		self.levelRImg2.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.levelRImg, nil, "as_rank_icon_" .. rankType, nil, , true)
		xyd.setUISpriteAsync(self.levelRImg2, nil, "as_rank_icon_" .. rankType .. "_" .. level_, nil, , true)
	end

	if selfScore < 2000 then
		self.labelLeftScore.text = math.fmod(selfScore, 100)
	else
		self.labelLeftScore.text = selfScore - 2000
	end

	if enemyScore < 2000 then
		self.labelRightScore.text = math.fmod(enemyScore, 100)
	else
		self.labelRightScore.text = enemyScore - 2000
	end

	local changeTextLeft = tostring(self.battleParams.self_change)
	local changeTextRight = tostring(self.battleParams.enemy_change)

	if self.battleParams.self_change > 0 then
		changeTextLeft = "+" .. changeTextLeft
	end

	if tonumber(self.battleParams.enemy_change) > 0 then
		changeTextRight = "+" .. changeTextRight
	end

	self.labelLeftScoreChange.text = "(" .. tostring(changeTextLeft) .. ")"

	if self.battleParams.enemy_change ~= 0 then
		self.labelRightScoreChange.gameObject:SetActive(true)

		self.labelRightScoreChange.text = "(" .. tostring(changeTextRight) .. ")"
	else
		self.labelRightScoreChange.gameObject:SetActive(false)
	end

	local aWinNum = 0
	local reports = self.battleParams.battle_reports

	for _, report in pairs(reports) do
		if report.isWin == 1 then
			aWinNum = aWinNum + 1
		end
	end

	self.leftScoreGroup.transform:Y(-150)
	self.rightScoreGroup.transform:Y(-150)

	self.labelResult1_.text = tostring(aWinNum)
	self.labelResult2_.text = tostring(#reports - aWinNum)
end

function Arena3V3ResultWindow:initArena3v3()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	self.labelLeftScoreText.text = __("SCORE2")
	self.labelRightScoreText.text = __("SCORE2")
	self.labelLeftScore.text = self.battleParams.score
	self.labelRightScore.text = self.battleParams.enemy_info.score
	local changeTextLeft = tostring(self.battleParams.self_change)
	local changeTextRight = tostring(self.battleParams.enemy_change)

	if self.battleParams.self_change > 0 then
		changeTextLeft = "+" .. changeTextLeft
	end

	if self.battleParams.enemy_change > 0 then
		changeTextRight = "+" .. changeTextRight
	end

	self.labelLeftScoreChange.text = "(" .. tostring(changeTextLeft) .. ")"
	self.labelRightScoreChange.text = "(" .. tostring(changeTextRight) .. ")"
	local aWinNum = 0
	local reports = self.battleParams.battle_reports

	for _, report in pairs(reports) do
		if report.isWin == 1 then
			aWinNum = aWinNum + 1
		end
	end

	self.labelResult1_.text = tostring(aWinNum)
	self.labelResult2_.text = tostring(#reports - aWinNum)
end

function Arena3V3ResultWindow:willClose()
	BaseWindow.willClose(self)

	if self.callback then
		self:callback(true)
	end
end

return Arena3V3ResultWindow
